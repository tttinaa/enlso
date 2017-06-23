import enlso.base.grad
alias enlso.base.grad, as Grad
import enlso.base.step
alias enlso.base.step, as Step
import Matrix
defmodule enlso.alg.firstOrder do
    @moduledoc """
    first order optimization: gradient descent, conjugate gradient, BFGS
    """
    def gd(f, x0, nmax \\ 5000, epsilon \\ 1.0e-5) do
    @doc """
    naive gradient descet
    """
        grad = Grad.grad!(x0, f)
        d = grad|>Enum.map(&(-1*&1))
        result = gd_helper(f, x0, nmax, epsilon, d, grad, n)
    end

    defp gd_helper(f, x0, nmax, epsilon, d, grad, n) do
        if Grad.norm(d) > epsilon && n<nmax do
            grad = Grad.grad!!(x0, f)
            d = grad|>Enum.map(&(-1*&1))
            alpha = Step.Armijo(grad, f, x0, d)
            x0 = alpha |> List.duplicate(length(d)) |> Enum.zip(d) |>
                Enum.map(fn(x) -> elem(x, 0)*elem(x, 1) end) |>
                Enum.zip(x0) |> Enum.map(fn(x) -> elem(x, 0)+elem(x, 1) end)
            n = n+1
            gd_helper(f, x0, nmax, epsilon, d, grad, n)
        end
        result = {x0, f(x0)}
    end

    def cg(f, x0, nmax \\ 5000, epsilon \\ 1.0e-5) do
    @doc """
    conjugate gradient
    """
        grad = Grad.grad!(x0, f)
        d = grad|>Enum.map(&(-1*&1))
        n = 0
        result = gd_helper(f, x0, nmax, epsilon, d, grad, n)
    end

    defp cg_helper(f, x0, nmax, epsilon, d, grad, n) do
        if Grad.norm(d) > epsilon && n < nmax do
            alpha = Step.Wolfe(grad, f, x0, d)
            x0 = alpha |> List.duplicate(length(d)) |> Enum.zip(d) |>
                Enum.map(fn(x) -> elem(x, 0)*elem(x, 1) end) |>
                Enum.zip(x0) |> Enum.map(fn(x) -> elem(x, 0)+elem(x, 1) end)
            temp = Grad.grad!(x0, f)
            beta = (temp|>Enum.zip(temp)|>Enum.map(fn(x) -> elem(x, 0)*elem(x, 1) end)|>Enum.sum) / 
                   (grad|>Enum.zip(grad)|>Enum.map(fn(x) -> elem(x, 0)*elem(x, 1) end)|>Enum.sum)
            d = beta |> List.duplicate(length(d)) |> Enum.zip(d) |>
                Enum.map(fn(x) -> elem(x, 0)*elem(x, 1) end) |>
                Enum.zip(x0) |> Enum.map(fn(x) -> elem(x, 0)-elem(x, 1) end)
            n = n+1
            grad = temp
            gd_helper(f, x0, nmax, epsilon, d, gard, n)
        end
        result = {x0, f(x0)}
    end

    def bfgs(f, x0, nmax \\ 5000, epsilon \\ 1.0e-5) do
    @doc """
    Broyden-Fletcher-Goldfarb-Shanno (BFGS) 
    """  
        x = List.duplicate(0, length(x0))
        # https://github.com/twist-vector/elixir-matrix
        b_matrix = Matrix.indent(length(x0))
        grad = Grad.grad!(x0, f)
        d = grad|>List.duplicate(length(grad))|>Matrix.mult(Matrix.transpose(b_matrix)|>Matrix.inv)|>
            Enum.at(0)|>Enum.map(&(-1*&1))
        result = bfgs_helper(f, x0, nmax, epsilon, d, grad, b_matrix, 0, n)
    end

    defp bfgs_helper(f, x0, nmax, epsilon, d, grad, b_matrix, s, n) do
        if Grad.norm(d) > epsilon && n < nmax do
            grad = Grad.grad!(x0, f)
            d = grad|>List.duplicate(length(grad))|>Matrix.mult(Matrix.transpose(b_matrix)|>Matrix.inv)|>
                Enum.at(0)|>Enum.map(&(-1*&1))
                alpha = Step.Wolfe(grad, f, x0, d)
            x = alpha |> List.duplicate(length(d)) |> Enum.zip(d) |>
                Enum.map(fn(x) -> elem(x, 0)*elem(x, 1) end) |>
                Enum.zip(x0) |> Enum.map(fn(x) -> elem(x, 0)+elem(x, 1) end)
            s = x|>Enum.zip(x0)|>Enum.map(fn(x) -> elem(x,0)-elem(x,1) end)
            yk =  Grad.grad!(x, f)|>Enum.zip(grad)|>Enum.map(fn(x) -> elem(x,0)-elem(x,1) end)
            if yk|>Enum.zip(s)|>Enum.map(fn(x) -> elem(x, 0)*elem(x, 1) end)|>Enum.sum > 0 do
                # B*s*s'*B
                s_temp = List.duplicate(0.0, length(s)) |> List.duplicate(length(s))
                for i <- 0..length(s)-1, do: s_temp |> Enum.at(i) |> List.replace_at(i, s|>
                                             Enum.at(i)|>List.duplicate(length(s)))
                b_matrix1_temp = s|>List.duplicate(length(s))|>Enum.zip(s_temp) |> Enum.map(fn(x) -> Tuple.to_list(x) end) |> 
                    Enum.map(fn(x) -> x|>Enum.at(0)|>Enum.zip(x|>Enum.at(1))|>Enum.map(fn(x)-> elem(x,0)*elem(x,1) end) end)
                b_matrix1 = b_matrix1|>Matrix.mult(b_matrix1_temp)|>Matrix.mult(b_matrix)
                # s'*B*s
                b_matrix2_temp = s|>List.duplicate(length(s))|>Matrix.mult(Matrix.transpose(b_matrix))|>Enum.at(0)
                b_matrix2 = b_matrix2_temp|>Enum.zip(b_matrix2_temp)|>Enum.map(fn(x) -> elem(x,0)*elem(x,1) end)|>Enum.sum
                # yk*yk'
                yk_temp = List.duplicate(0.0, length(yk)) |> List.duplicate(length(yk))
                for i <- 0..length(yk)-1, do: yk_temp |> Enum.at(i) |> List.replace_at(i, yk|>
                                             Enum.at(i)|>List.duplicate(length(yk)))
                b_matrix3 = yk|>List.duplicate(length(yk))|>Enum.zip(yk)|>Enum.map(fn(x) -> Tuple.to_list(x) end) |> 
                    Enum.map(fn(x) -> x|>Enum.at(0)|>Enum.zip(x|>Enum.at(1))|>Enum.map(fn(x)-> elem(x,0)*elem(x,1) end) end)
                # yk'*s
                b_matrix4 = yk|>Enum.zip(s)|>Enum.map(fn(x) -> elem(x,0)*elem(x,1) end)|>Enum.sum
                # B-b_matrix1/b_matrix2
                b_matrix5 = b_matrix|>Matrix.sub(Matrix.mult(b_matrix1, 1/b_matrix2|>List.duplicate(length(x0)|>List(length(x0)))))
                # b_matrix3/b_matrix4
                b_matrix6 = b_matrix3|>Matrix.mult(b_matrix3, 1/b_matrix4|>List.duplicate(length(x0)|>List(length(x0))))

                b_matrix = Matrix.add(b_matrix5, b_matrix6)         
            end
            n = n+1
            x0 = x
            bfgs_helper(f, x0, nmax, epsilon, d, grad, b_matrix, s, n)
        end
        result = {x0, f(x0)}
    end
end