class BooksController < ApplicationController

  def top
  end

  def index
    @books = Book.all
    @book  = Book.new
  end

  def create
    @book = Book.new(book_params)
    @books = Book.all
    if @book.save
      flash[:success] = "Book was successfully created."
      redirect_to book_path(book)
    else
      render action: :index
    end
  end

  def show
    @book = Book.find(params[:id])
  end

  def edit
    @book = Book.find(params[:id])
  end

  def update
    @book = Book.find(params[:id])
    @books = Book.all
    if @book.update(book_params)
      flash[:success] = "Book was successfully updated."
      redirect_to book_path(book.id)
    else 
      render action: :edit
    end
  end

  def destroy
    book = Book.find(params[:id])
    if book.destroy
      flash[:success] = "Book was successfully destroyed."
      redirect_to books_path
    else
      flash[:success] = "Failed to delete Book."
      redirect_to books_path
    end
  end

  private
  def book_params
    params.require(:book).permit(:title, :body)
  end
end
